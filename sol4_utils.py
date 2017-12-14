############################################################
# Imports
############################################################

import numpy as np
from scipy.misc import imread as imread
from skimage.color import rgb2gray
from scipy.signal import convolve2d, convolve
from scipy.ndimage.filters import convolve as multi_convolve

############################################################
# Constants
############################################################

GRAYSCALE_IMAGE_CODE = 1
NUMBER_OF_COLORS = 255
RGB_DIMENSION = 3
MIN_DIMENSION = 16
CONVOLUTION_VECTOR = np.array([1, 1]).astype(np.float64)

############################################################
# Methods
############################################################


def read_image(filename, representation):
    """
    This method reads an image file and converts it into a given representation.
    :param filename: A string containing the image filename to read.
    :param representation: The representation code, either 1 or 2 defining whether the output
    should be a grayscale image (1) or an RGB image (2).
    :return: An image, represented by a matrix of type np.float64 with intensities
    (either grayscale or RGB channel intensities) normalized to the range [0, 1].
    """
    im = imread(filename)
    im = im.astype(np.float64)
    # Check if need to convert RGB to grayscale
    if (representation == GRAYSCALE_IMAGE_CODE) and (im.ndim == RGB_DIMENSION):
        im = rgb2gray(im)
    im /= NUMBER_OF_COLORS
    return im


def compute_filter_vec(kernel_size):
    """
    This method computes the gaussian filter.
    :param kernel_size: The size of the gaussian filter in each dimension (an odd integer).
    :return: The gaussian filter.
    """
    if kernel_size == 1:
        kernel = np.array([1]).astype(np.float64)
    else:
        kernel = CONVOLUTION_VECTOR
        # A consequent 1D convolutions of [1 1] with itself for a row of the binomial coefficients
        for i in range(kernel_size - 2):
            kernel = convolve(kernel, CONVOLUTION_VECTOR)
    normalize_kernel = np.array([kernel / np.sum(kernel)])
    return normalize_kernel


def expand(im, filter_vec):
    """
    This method expands the image.
    :param im: A grayscale image with double values in [0, 1].
    :param filter_vec: The gaussian filter.
    :return: An expanded image.
    """
    rows = im.shape[0] * 2
    cols = im.shape[1] * 2
    # Zero padding
    enlarged_image = np.zeros((rows, cols))
    enlarged_image[::2, ::2] = im
    # Blur the image
    enlarged_image = multi_convolve(enlarged_image, 2 * filter_vec)
    enlarged_image = multi_convolve(enlarged_image, 2 * filter_vec.transpose())
    return enlarged_image


def reduce(im, filter_vec):
    """
    This method reduces the image.
    :param im: a grayscale image with double values in [0, 1].
    :param filter_vec: The gaussian filter.
    :return: A reduced image.
    """
    # Blur the image
    reduced_image = multi_convolve(im, filter_vec)  # Convolve a row vector
    reduced_image = multi_convolve(reduced_image, filter_vec.transpose())  # Convolve a col vector
    # Make sub-sample
    reduced_image = reduced_image[::2, ::2]
    return reduced_image


def build_gaussian_pyramid(im, max_levels, filter_size):
    """
    This method constructs a Gaussian pyramid.
    :param im: A grayscale image with double values in [0, 1].
    :param max_levels: The maximal number of levels in the resulting pyramid.
    :param filter_size: The size of the Gaussian filter (an odd scalar that represents a squared
     filter) to be used in constructing the pyramid filter.
    :return: A gaussian pyramid (the resulting pyramid pyr as a standard python array),
    and a filter_vec which is 1D-row of size filter_size used for the pyramid construction.
    """
    filter_vec = compute_filter_vec(filter_size)
    # pyr[0] has the resolution of the given input image im
    pyr = [im]
    # Reducing the image and construct a Gaussian pyramid
    for i in range(1, max_levels):
        reduced_image = reduce(pyr[i-1], filter_vec)
        height_dim = reduced_image.shape[0]
        width_dim = reduced_image.shape[1]
        # The minimum dimension of the lowest resolution image in the pyramid is not smaller than 16
        if height_dim < MIN_DIMENSION or width_dim < MIN_DIMENSION:
            break
        pyr.append(reduced_image)
    return pyr, filter_vec


def compute_kernel(kernel_size):
    """
    This method computes the 2D gaussian kernel.
    :param kernel_size: The size of the gaussian kernel in each dimension (an odd integer).
    :return: The 2D gaussian kernel.
    """
    # Check if the kernel size is 1X1
    if kernel_size == 1:
        kernel = np.array([1]).astype(np.float64)
    else:
        # A consequent 1D convolutions of [1 1] with itself for a row of the binomial coefficients
        kernel = CONVOLUTION_VECTOR
        for i in range(kernel_size - 2):
            kernel = convolve(kernel, CONVOLUTION_VECTOR)
    kernel = kernel[:, None]  # Row -> col
    # Compute a 2D gaussian kernel
    two_d_kernel = convolve2d(kernel, np.transpose(kernel)).astype(np.float64)
    normalize_two_d_kernel = two_d_kernel / np.sum(two_d_kernel)
    return normalize_two_d_kernel


def blur_spatial(im, kernel_size):
    """
    This method performs image blurring using 2D convolution between the image f
    and a gaussian kernel g.
    :param im: The input image to be blurred (grayscale float64 image).
    :param kernel_size: The size of the gaussian kernel in each dimension (an odd integer).
    :return: The output is blurry image (grayscale float64 image).
    """
    normalize_two_d_kernel = compute_kernel(kernel_size)
    convolve_image = convolve2d(im,  normalize_two_d_kernel, mode='same')
    return convolve_image


def build_laplacian_pyramid(im, max_levels, filter_size):
    """
    This method constructs a Laplacian pyramid.
    :param im: A grayscale image with double values in [0, 1].
    :param max_levels: The maximal number of levels in the resulting pyramid.
    :param filter_size: The size of the Gaussian filter (an odd scalar that represents a squared
     filter) to be used in constructing the pyramid filter.
    :return: A Laplacian pyramid (the resulting pyramid pyr as a standard python array),
    and a filter_vec which is 1D-row of size filter_size used for the pyramid construction.
    """
    gaussian_pyramid, filter_vec = build_gaussian_pyramid(im, max_levels, filter_size)
    laplacian_pyramid = []
    pyr_max_levels = len(gaussian_pyramid) - 1
    # Construct a Laplacian pyramid by the formula
    for i in range(pyr_max_levels):
        computed_pyramid = gaussian_pyramid[i] - expand(gaussian_pyramid[i+1], filter_vec)
        laplacian_pyramid.append(computed_pyramid)
    # Add the last image
    laplacian_pyramid.append(gaussian_pyramid[pyr_max_levels])
    return laplacian_pyramid, filter_vec


def laplacian_to_image(lpyr, filter_vec, coeff):
    """
    This method reconstructs of an image from its Laplacian Pyramid.
    :param lpyr: A Laplacian pyramid.
    :param filter_vec: The gaussian filter.
    :param coeff: A vector. The vector size is the same as the number of levels in the pyramid lpyr.
    :return: The original image.
    """
    loop_counter = len(lpyr) - 2
    im = lpyr[loop_counter + 1]
    # Reconstruction of an image from its Laplacian Pyramid
    while loop_counter >= 0:
        expanded_image = expand(im, filter_vec)
        #  Multiply each level i of the Laplacian pyramid by its corresponding coefficient
        multiply_coefficient = lpyr[loop_counter] * coeff[loop_counter]
        im = expanded_image + multiply_coefficient
        loop_counter -= 1
    return im


def pyramid_blending(im1, im2, mask, max_levels, filter_size_im, filter_size_mask):
    """
    Thid method handles the pyramid blending.
    :param im1: A input grayscale image to be blended.
    :param im2: A input grayscale image to be blended.
    :param mask: A boolean (i.e. dtype == np.bool) mask containing True and False representing
    which parts of im1 and im2 should appear in the resulting im_blend.
    :param max_levels: A parameter that was used when generating the Gaussian and Laplacian pyrs.
    :param filter_size_im: The size of the Gaussian filter (an odd scalar that represents a squared
    filter) which defining the filter used in the construction of the Laplacian pyramids
    of im1 and im2.
    :param filter_size_mask: The size of the Gaussian filter(an odd scalar that represents a squared
     filter) which defining the filter used in the construction of the Gaussian pyramid of mask.
    :return: A valid blanded grayscale image in the range [0, 1].
    """
    # Construct the Laplacian Pyramids lpyr1 and lpyr2
    lpyr1, filter_vec1 = build_laplacian_pyramid(im1, max_levels, filter_size_im)
    lpyr2, filter_vec2 = build_laplacian_pyramid(im2, max_levels, filter_size_im)
    # Construct a Gaussian pyramid gpyr_mask for the provided mask
    gpyr_mask, filter_vec_mask = build_gaussian_pyramid(mask.astype(np.float64), max_levels,
                                                        filter_size_mask)
    # Construct the Laplacian pyramid lpyr_out of the blended image for each level k by formula
    lpyr_out = []
    for i in range(len(gpyr_mask)):
        calculation = gpyr_mask[i] * lpyr1[i] + (1 - gpyr_mask[i]) * lpyr2[i]
        lpyr_out.append(calculation)
    # Reconstruct the resulting blended image from the Laplacian pyramid lpyr_out
    im_blend = laplacian_to_image(lpyr_out, filter_vec1, np.ones(len(lpyr_out)))
    im_blend = np.clip(im_blend, 0, 1)
    return im_blend
